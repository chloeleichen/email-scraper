import smtplib
import csv
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email.mime.application import MIMEApplication

SENDER_EMAIL='xxx@gmail.com'
SENDER_PASSWORD = '*****'

def no_blank(fd):
    try:
        while True:
            line = next(fd)
            if len(line.strip()) != 0:
                yield line
    except:
        return

def get_contact():
    f = open('./sample.csv')
    csv_f = csv.reader(no_blank(f))

    recipients = []
    for row in csv_f:
        recipients.append(row)
    return recipients

def send_email(receiver_email, subject, body):
    msg = MIMEMultipart()
    msg['Subject'] = subject
    msg['From'] = SENDER_EMAIL
    msg['To'] = receiver_email

    msgText = MIMEText('<b>%s</b>' % (body), 'html')
    msg.attach(msgText)

    with open('./sample.jpg', 'rb') as fp:
        img = MIMEImage(fp.read())
        img.add_header('Content-Disposition', 'attachment', filename="sample.jpg")
        msg.attach(img)

    pdf = MIMEApplication(open("sample.pdf", 'rb').read())
    pdf.add_header('Content-Disposition', 'attachment', filename="sample.pdf")
    msg.attach(pdf)
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.ehlo()
        server.starttls()
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.sendmail(SENDER_EMAIL, receiver_email, msg.as_string())
        print(f'sent email to {receiver_email}')
    except:
        print('error')



def send_emails():
    contacts = get_contact()
    for contact in contacts:
        send_email(contact[1], f'proposal for {contact[0]}', contact[0])


if __name__ == '__main__':
    send_emails()



